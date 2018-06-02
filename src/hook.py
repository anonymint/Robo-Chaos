from urllib.request import urlopen
from urllib.request import Request
import urllib.error as error
import os

HOOK_URL_NAME = "hook_url"

def send_slack_hook(event, context):
    data_template_default = '{{"text": "*{}*\n {}"}}'
    url = os.environ.get(HOOK_URL_NAME, "").strip()
    if len(url) == 0:
        raise Exception('No hook url provided via Environment', HOOK_URL_NAME)

    headers = {'Content-Type': 'application/json'}
    for record in event['Records']:
        sns = record['Sns']
        title = sns['Subject']
        message = sns['Message']
        data = data_template_default.format(title, message)
        print(data)
        data_encoded = data.encode('utf-8')
        try:
            req = Request(url, headers=headers, method='POST',
                          data=data_encoded)
            res = urlopen(req)
            print(res)
        except error.HTTPError as e:
            raise Exception('status:', e.code, 'reason:', e.reason, 'url:', e.url)



def handler(event, context):
    """
    Main Lambda function
    """
    send_slack_hook(event, context)
