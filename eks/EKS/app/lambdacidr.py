import json
import boto3
from crhelper import CfnResource

helper = CfnResource()

@helper.create
@helper.update
def get_cidr(event, _):
    ec2 = boto3.resource('ec2')
    vpc = ec2.Vpc(id=event['ResourceProperties']['vpc'])
    helper.Data['Cidr'] = vpc.cidr_block
@helper.delete
def no_op(_, __):
    pass

def handler(event, context):
    helper(event, context)