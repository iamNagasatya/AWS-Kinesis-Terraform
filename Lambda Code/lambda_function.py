import json
import csv
import boto3
import uuid


def lambda_handler(event, context):
    region = 'us-east-1'
    record_list = []
    try:
        s3=boto3.client('s3')
        kinesis=boto3.client('kinesis',region_name=region)
        bucket=event['Records'][0]['s3']['bucket']['name']
        key=event['Records'][0]['s3']['object']['key']
        print('Bucket:', bucket,'Key:', key)
        csv_file=s3.get_object(Bucket=bucket,Key=key)
        record_list=csv_file['Body'].read().decode('utf-8').split('\n')
        csv_reader=csv.reader(record_list,delimiter=',',quotechar='"')
        firstrecord=True
        for row in csv_reader:
            if(firstrecord):
                firstrecord=False
                continue
            id=row[0]
            case_number=row[1]
            date=row[2]
            block=row[3]
            iucr_code=row[4]
            location_desc=row[5]
            arrest=row[6]
            domestic=row[7]
            beat_num=row[8]
            district_code=row[9]
            ward_no=row[10]
            community_code=row[11]
            fbi_code=row[12]
            x_coordinate=row[13]
            y_coordinate=row[14]
            year=row[15]
            date_of_update=row[16]
            latitude=row[17]
            longitude=row[18]
            location=row[19]
 
 
            data={'id':id,'case_number':case_number,'date':date,'block':block,'iucr_code':iucr_code,
                  'location_desc':location_desc,'arrest':arrest,'domestic':domestic,
                  'beat_num':beat_num,'district_code':district_code,'ward_no':ward_no,
                  'community_code':community_code,'fbi_code':fbi_code,
                  'x_coordinate':x_coordinate,'y_coordinate':y_coordinate,'year':year,
                  'date_of_update':date_of_update,'latitude':latitude,'longitude':longitude,
                  'location':location}
                  
            response=kinesis.put_record(StreamName='kds',Data=json.dumps(data),PartitionKey=str(uuid.uuid4()))
            print(response)
 
    except Exception as e:
        print(str(e))
 
    return {
        'statusCode': 200,
        'body': json.dumps('csv to Kinesis Data Stream success')
            }
            