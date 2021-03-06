import os
import boto3
import random
import tasks as tasks
import helper as helper

REGIONS_VAIRABLE_NAME = "regions"
ASG_GROUP_NAME = "asg_group_name"
ASG_TERMINATION_TAG = "chaos-termination-prob"
TERMINATION_UNLEASH_NAME = "unleash_chaos"
PROBABILITY_NAME = "probability"
ALERT_ARN_NAME = "sns_alert_arn"
TARGET_ACCOUNT_NAME = "target_accounts"
DEFAULT_PROBABILITY = 1.0 / 6.0  # one in six of hours unit


def get_target_account(context):
    targets = os.environ.get(TARGET_ACCOUNT_NAME, "").strip()
    if len(targets) > 0:
        return [t.strip() for t in targets.split(",")]
    else:
        return [context.invoked_function_arn.split(":")[4]]


def get_regions(context):
    regions = os.environ.get(REGIONS_VAIRABLE_NAME, "").strip()
    if len(regions) > 0:
        # if provided environments variables regions
        return [r.strip() for r in regions.split(",")]
    else:
        # default get region from lambda arn
        return [context.invoked_function_arn.split(":")[3]]


def get_global_probability(default):
    prob = os.environ.get(PROBABILITY_NAME, "").strip()
    if len(prob) == 0:
        return DEFAULT_PROBABILITY

    return convert_valid_prob_float(prob, default)


def run_chaos(accounts, regions, default_prob):
    results = []
    for account in accounts:
        for region in regions:
            asgs = get_asgs(account, region)
            instances = get_instances_randomly(account, region, asgs, default_prob)
            results.extend(
                run_chaos_each_account_region(account, instances, region))
    return results


def get_asgs(account, region):
    given_asg = os.environ.get(ASG_GROUP_NAME, "").strip()
    asgs = assumeRole(account, "autoscaling", region)
    for res in asgs.get_paginator("describe_auto_scaling_groups").paginate():
        for asg in res.get("AutoScalingGroups", []):
            if len(given_asg) > 0:
                group_names = given_asg.split(",")
                if asg['AutoScalingGroupName'] in group_names:
                    yield asg
            else:
                yield asg


def get_asg_tag(asg, tagname, default):
    for tag in asg.get("Tags", []):
        if tag.get("Key", "") == tagname:
            return tag.get("Value", "")
    return default


def get_probability(asg, default):
    custom_prob = get_asg_tag(asg, ASG_TERMINATION_TAG, None)
    if custom_prob is None:
        return default

    # check for valid number
    return convert_valid_prob_float(custom_prob, default)


def get_instances_randomly(account, region, asgs, probability):
    termination_instances = []
    ec2_client = assumeRole(account, "ec2", region)
    for asg in asgs:
        instances = asg.get("Instances", [])
        if len(instances) == 0:
            continue

        # isntance-state-code == 16 is running http://boto3.readthedocs.io/en/latest/reference/services/ec2.html#EC2.Client.describe_instance_status
        running_instances = ec2_client.describe_instance_status(Filters=[{'Name': 'instance-state-code', 'Values': ['16']}], InstanceIds=[i['InstanceId'] for i in instances])
        instances = list(filter(lambda e: e['InstanceId'] in [e['InstanceId'] for e in running_instances['InstanceStatuses']], instances))

        # after filter only instances with running state, if size is > 0 go ahead
        if len(instances) == 0:
            continue

        asg_prob = get_probability(asg, probability)
        # if asg_prob > random_figture then pick one to destroy
        if asg_prob > random.random():
            instance_id = random.choice(instances).get("InstanceId", None)
            termination_instances.append((asg["AutoScalingGroupName"], instance_id))

    return termination_instances


def run_chaos_each_account_region(account, instances, region):
    unleash_chaos = os.environ.get(TERMINATION_UNLEASH_NAME, "").strip()
    results = []
    for i in instances:
        result = tasks.calling_tasks_random(account, i, region, dryrun=(
            not helper.string_to_bool(unleash_chaos)))
        results.append(result)
    return results


def convert_valid_prob_float(value, default):
    """
    Helper method to check and convert float to valid probability value

    :param value: probability value supposed to be 0 - 1 range
    :type value: float
    :param default: default value if any error
    :type default: float
    :return: valid probability value
    :rtype: float
    """
    try:
        value = float(value)
    except ValueError:
        return default

        # check prob 0.0 - 1.0 only
    if value < 0 or value > 1:
        return default

    return value


def alert(data):
    """
    Passing list of Tasks that has been executing or DRY-RUN to publish on SNS

    :param data: message
    :type List of str
    """
    alert_arn = os.environ.get(ALERT_ARN_NAME, '').strip()
    if len(alert_arn) > 0 and data:
        sns_client = boto3.client('sns')
        title = "Choas Engineer Team"
        message = 'Here is list of jobs we have done \n'
        message += ''.join(['\n * ' + d for d in data])
        sns_client.publish(TopicArn=alert_arn,
                           Subject=title,
                           Message=message)


def assumeRole(account, service, region):
    """

    This function is used for master-target account perspective, to assume role
    in the target account to do the work

    :param account: 13 digit aws account to assume the role
    :type account: str
    :param service: AWS service client
    :type service: str
    :param region: Region you want to setup client into
    :type region: str
    :return: Client object
    :rtype: Boto3 Client
    """
    sts_client = boto3.client('sts')
    assumeRoleObject = sts_client.assume_role(
        RoleArn='arn:aws:iam::' + account + ':role/chaos-engineer',
        RoleSessionName='AssumeRoleChaosEngineer'
    )

    credentials = assumeRoleObject['Credentials']
    client = boto3.client(
        service,
        region_name=region,
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken'],
    )
    return client


"""
Main Handler function
"""


def handler(event, context):
    """
    Main Lambda function
    """
    accounts = get_target_account(context)
    regions = get_regions(context)
    global_prob = get_global_probability(DEFAULT_PROBABILITY)
    result = run_chaos(accounts, regions, global_prob)
    alert(result)
    return result