# Clean up

To clean up failed jobs because of a Cloudflare outage, for instance, run this command:
```bash
$ kubectl delete jobs -n ddns --field-selector status.successful=0
```