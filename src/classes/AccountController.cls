public with sharing class AccountController {

    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('Account ID is required');
        }

        List<Account> accounts = [
                SELECT Id, Name, AccountNumber, Industry
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
        ];

        if (accounts.isEmpty()) {
            throw new AuraHandledException('Account not found');
        }

        return accounts[0];
    }
}