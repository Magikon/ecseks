from crhelper import CfnResource

helper = CfnResource()

@helper.create
@helper.update
def sum_2_numbers(event, _):
    s = int(event['ResourceProperties']['No1']) + int(event['ResourceProperties']['No2'])
    helper.Data['Sum'] = s
@helper.delete
def no_op(_, __):
    pass

def handler(event, context):
    helper(event, context)