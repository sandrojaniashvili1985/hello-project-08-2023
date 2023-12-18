import {Prop, Schema, SchemaFactory} from '@nestjs/mongoose';
import {HydratedDocument, model} from 'mongoose';

export type ScenarioDocument = HydratedDocument<Scenario>;

@Schema()
export class Scenario {
  @Prop()
  name: string;

  @Prop()
  link: string;

  @Prop()
  action: string;

  @Prop()
  back: string;
}

export const ScenarioSchema = SchemaFactory.createForClass(Scenario);
export default model('scenario', ScenarioSchema);
