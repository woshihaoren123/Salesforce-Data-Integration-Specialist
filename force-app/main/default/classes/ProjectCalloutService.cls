public class ProjectCalloutService {
    //Complete the implementation for business and callout logic
    @InvocableMethod(label='Callout POST opps to PMS')
    public static void postOpportunityToPMS(List<Id> oppIds){
        System.enqueueJob(new QueueablePMSCall(oppIds[0]));
    }
    
    class QueueablePMSCall implements Queueable, Database.AllowsCallouts{
        
        private Id oppId;
        
        public QueueablePMSCall(Id oppId) {
            this.oppId = oppId;
        }
        
        public void execute(System.QueueableContext ctx) {
            
            String token = ServiceTokens__c.getValues('ProjectServiceToken').Token__c;
            String body = getBody();
            postToPMS(token, body);
        }
        
        private String getBody() {
            Opportunity opp = [SELECT Id, Name, Account.Name, CloseDate, Amount
                               FROM Opportunity
                               WHERE Id =: oppId];
            System.debug(opp);
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('opportunityId', opp.Id);
            gen.writeStringField('opportunityName', opp.Name);
            gen.writeStringField('accountName', opp.Account.Name);
            gen.writeStringField('closeDate', String.ValueOf(opp.CloseDate).mid(0,10));
            gen.writeStringField('amount', String.ValueOf(opp.Amount));
            gen.writeEndObject();
            return gen.getAsString();
        }
    }
    
    @Future(callout=true)
    private static void postToPMS(String token, String body) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:ProjectService');
        request.setMethod('POST');
        request.setHeader('token', token);
        request.setHeader('Content-Type', 'application/json;charset=utf-8');
        request.setBody(body);
        HttpResponse response = new Http().send(request);
    }
    
}