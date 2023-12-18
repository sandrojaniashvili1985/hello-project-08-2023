export interface Scenario {
  showReport: any;
  name: string;
  created: Date;
  passed: boolean;
  lastResult?: {passed: boolean, created: Date, fullReport: any};
}
