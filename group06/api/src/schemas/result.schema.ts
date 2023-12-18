import { Prop, SchemaFactory, Schema } from '@nestjs/mongoose';
import { HydratedDocument, model, SchemaTypes } from 'mongoose';

export type ResultDocument = HydratedDocument<Result>;

@Schema()
export class Result {
  @Prop()
  scenario: string;

  @Prop({ default: Date.now })
  created: Date;

  @Prop({ type: SchemaTypes.Mixed })
  fullReport: any;

  @Prop()
  passed: boolean;
}

export const ResultSchema = SchemaFactory.createForClass(Result);
export default model('result', ResultSchema);
