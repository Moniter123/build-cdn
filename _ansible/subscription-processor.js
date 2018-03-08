var AWS = require("aws-sdk");

var TASK_QUEUE_URL = process.env.TASK_QUEUE_URL;
var AWS_REGION = process.env.AWS_REGION;

var sqs = new AWS.SQS({region: AWS_REGION});

function deleteMessage(receiptHandle, cb) {
    sqs.deleteMessage({
        ReceiptHandle: receiptHandle,
        QueueUrl: TASK_QUEUE_URL
    }, cb);
}

function work(task, cb) {
    task = JSON.parse(task);

    var AWS = require('aws-sdk');
    // Set the region
    AWS.config.update({region: 'eu-central-1'});

    // Create the DynamoDB service object
    var ddb = new AWS.DynamoDB({apiVersion: '2012-10-08'});

    var params = {
        TableName: 'subscriptions',
        Item: {
            'id': {S: task.id},
            'created_at': {N: task.created_at},
            'data': {S: task.data}
        }
    };

    ddb.putItem(params, function(err, data) {
        if (err) {
            throw err;
        } else {
            cb();
        }
    });
}

exports.handler = function(event, context, callback) {
    work(event.Body, function(err) {
        if (err) {
            callback(err);
        } else {
            deleteMessage(event.ReceiptHandle, callback);
        }
    });
};