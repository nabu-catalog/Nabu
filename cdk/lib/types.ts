import type { ICertificate } from 'aws-cdk-lib/aws-certificatemanager';
import type { IHostedZone } from 'aws-cdk-lib/aws-route53';
import type { IBucket } from 'aws-cdk-lib/aws-s3';

export type Environment = {
  readonly appName: string,
  readonly region: string,
  readonly env: string,
  readonly railsEnv: string,
  readonly branchNames: string[],
  readonly account: string,
  readonly zoneName: string,
  readonly acmeValue: string,
};

export type AppProps = Environment & {
  readonly catalogBucket: IBucket,
  readonly zone: IHostedZone,
  readonly tempCertificate: ICertificate,
};
