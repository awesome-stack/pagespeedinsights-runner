#!/bin/sh
cd $(dirname $0)

if [ "${SLACK_INCOMING_WEBHOOK_URL}" = "" ]
then
    echo 'Please set the Environment variable "SLACK_INCOMING_WEBHOOK_URL".'
    exit 1
fi

if [ "${SLACK_CHANNEL_NAME}" = "" ]
then
    echo 'Please set the Environment variable "SLACK_CHANNEL_NAME".'
    exit 1
fi

if [ "${SLACK_USERNAME}" = "" ]
then
    SLACK_USERNAME='PageSpeed Insights'
fi

if [ "${SLACK_ICON_EMOJI}" = "" ]
then
    SLACK_ICON_EMOJI=':rainbow:'
fi

REPORT_ROOT_PATH='report'
REPORT_FILE_SUFFIX='psi.report.json'

createMessge () {
    json_path=$1
    datetime_value=`basename ${json_path} | sed "s#_${REPORT_FILE_SUFFIX}##g"`
    score=`cat ${json_path} | jq '.ruleGroups.SPEED.score'`
    url=`cat ${json_path} | jq '.id' | sed 's#\"##g'`
    fcp_median=`cat ${json_path} | jq '.loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.median'`
    fcp_category=`cat ${json_path} | jq '.loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.category' | sed 's#\"##g'`
    dcl_median=`cat ${json_path} | jq '.loadingExperience.metrics.DOM_CONTENT_LOADED_EVENT_FIRED_MS.median'`
    dcl_category=`cat ${json_path} | jq '.loadingExperience.metrics.DOM_CONTENT_LOADED_EVENT_FIRED_MS.category' | sed 's#\"##g'`
    echo "Score: ${score}, FCP: ${fcp_median}ms(${fcp_category}), DCL: ${dcl_median}ms(${dcl_category}), URL: ${url}, DateTime: ${datetime_value}"
}

message=''
raw_data_path_array=`find ${REPORT_ROOT_PATH} -name "*${REPORT_FILE_SUFFIX}"`
for raw_data_path in $raw_data_path_array; do
    message+=`createMessge ${raw_data_path}`"\n"
done
curl -X POST --data-urlencode "payload={\"channel\": \"${SLACK_CHANNEL_NAME}\", \"username\": \"${SLACK_USERNAME}\", \"text\": \"${message}\", \"icon_emoji\": \"${SLACK_ICON_EMOJI}\"}" ${SLACK_INCOMING_WEBHOOK_URL}
