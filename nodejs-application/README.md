# NodeJS application

There you can find gitlab pipeline with 3 stages:
- `Build` - installing npm dependencies and building the application with **npm build**
- `Lint & Jest test in parallel` - performing lint and jest test of build artifacts
- `Publish/Deploy` - publishing artifacts to AWS S3 bucket, discovering and invalidating appropriate AWS Cloudfront distributions
