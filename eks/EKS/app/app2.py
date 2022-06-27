import subprocess
from crhelper import CfnResource


helper = CfnResource()

@helper.create
@helper.update
def test_eksctl(event, _):
    test = f'eksctl version'
    s = subprocess.run(
        f'{test}',
        encoding='utf-8',
        capture_output=True,
        shell=True,
        check=False
    )
    helper.Data['Eks'] = s
@helper.delete
def no_op(_, __):
    pass

def handler(event, context):
    helper(event, context)