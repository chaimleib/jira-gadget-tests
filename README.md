# JIRA Gadget Tests

Examples of dashboard gadgets and gadget components for Atlassian's JIRA issue tracking system.

Before running any of the scripts, run
    
```bash
cp jira-config.yml{.template,}
```

and edit `jira-config.yml` to put in your JIRA email, password, and host URI.

If you keep getting '401: Unauthorized' errors, check to see if your JIRA host requires e-mail address-formatted usernames (joe@example.com) or simple identifiers without a realm (joe).

