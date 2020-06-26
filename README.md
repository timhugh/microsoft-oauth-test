# Microsoft OAuth 2.0 Example

To test:

```
CLIENT_ID=abcde CLIENT_SECRET=fghij TENANT_ID=klmno PORT=3000 CALLBACK_PATH=/api/oauth/callback ruby app.rb
```

Or use a .env file:
```
env $(cat .env | grep -v "#" | xargs) ruby app.rb
```

Then direct your browser to http://localhost:3000/login (change the port if you picked a different one) and you'll be run through the oauth token flow
