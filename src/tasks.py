"""
Chaos Tasks
"""

import random
import helper as helper
import chaos as chaos


def terminate_instance_worker(account, instance, region, dryrun=True):
    task_definition = "Terminate"
    result = format_result_str(task_definition, dryrun, instance[1], instance[0], region, account)
    if dryrun:
        return result

    ec2 = chaos.assumeRole(account, "ec2", region)
    ec2.terminate_instances(InstanceIds=[instance[1]])
    result = "Terminate {} from {} in {}".format(instance[1],
                                                 instance[0], region)
    helper.printlog(result)
    return result


def max_cpu_worker(account, instance, region, dryrun=True):
    task_definition = "Max out CPU"
    result = format_result_str(task_definition, dryrun, instance[1], instance[0], region, account)
    if dryrun:
        return result

    ssm = chaos.assumeRole(account, "ssm", region)
    resp = ssm.send_command(
        DocumentName="AWS-RunShellScript",
        Parameters={
            'commands': ["cat << EOF > /tmp/infiniteburn.sh", "#!/bin/bash",
                         "while true;", " do openssl speed;", "done", "EOF",
                         "",
                         "# 32 parallel 100% CPU tasks should hit even the biggest EC2 instances",
                         "for i in {1..32}", "do",
                         " nohup /bin/bash /tmp/infiniteburn.sh > /dev/null 2>&1 &",
                         "done"]},
        InstanceIds=[instance[1]]
    )
    helper.printlog(resp)
    return result

def kill_java_process(account ,instance, region, dryrun=True):
    task_definition = "Custom Task"
    result = format_result_str(task_definition, dryrun, instance[1], instance[0], region, account)
    if dryrun:
        return result

    ssm = chaos.assumeRole(account, "ssm", region)
    resp = ssm.send_command(
        DocumentName="AWS-RunShellScript",
        Parameters={
            'commands': ["#!/bin/bash",
                         "cat << EOF > /tmp/kill_java_loop.sh",
                         "#!/bin/bash", "while true;", "do",
                         " pkill -KILL -f java", " sleep 1", "done", "EOF", "",
                         "nohup /bin/bash /tmp/kill_java_loop.sh > /dev/null 2>&1 &"]},
        InstanceIds=[instance[1]]
    )
    helper.printlog(resp)
    return result

def kill_nginx_process(account ,instance, region, dryrun=True):
    task_definition = "Custom Task"
    result = format_result_str(task_definition, dryrun, instance[1], instance[0], region, account)
    if dryrun:
        return result

    ssm = chaos.assumeRole(account, "ssm", region)
    resp = ssm.send_command(
        DocumentName="AWS-RunShellScript",
        Parameters={
            'commands': ["#!/bin/bash",
                         "cat << EOF > /tmp/kill_nginx_loop.sh",
                         "#!/bin/bash", "while true;", "do",
                         " pkill -KILL -f nginx", " sleep 1", "done", "EOF", "",
                         "nohup /bin/bash /tmp/kill_nginx_loop.sh > /dev/null 2>&1 &"]},
        InstanceIds=[instance[1]]
    )
    helper.printlog(resp)
    return result


def custom_task(account ,instance, region, dryrun=True):
    """
    This task is just place holder so you can add and put custom_task in the TASKS list below and you're good to go
    """
    task_definition = "Custom Task"
    result = format_result_str(task_definition, dryrun, instance[1], instance[0], region, account)
    if dryrun:
        return result

    ssm = chaos.assumeRole(account, "ssm", region)
    resp = ssm.send_command(
        DocumentName="AWS-RunShellScript",
        Parameters={
            'commands': ["echo \"I'm in `hostname`\""]},
        InstanceIds=[instance[1]]
    )
    helper.printlog(resp)
    return result


def format_result_str(task, dryrun, instance_id, asg_name, region, account):
    dryrun_str = "[DRY-RUN]" if dryrun else ""
    return "{} {} {} from {} in {} at account {}".format(task, dryrun_str, instance_id, asg_name, region, account)


TASKS = [
    terminate_instance_worker,
    max_cpu_worker,
    kill_java_process,
    kill_nginx_process
]


def calling_tasks_random(account, i, region, dryrun=True):
    task_to_run = random.choice(TASKS)
    return task_to_run(account, i, region, dryrun)
