import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, model } from 'mongoose';

export type SettingsDocument = HydratedDocument<Settings>;

@Schema()
export class Settings {
  @Prop()
  prodUrl: string;

  @Prop()
  stageUrl: string;

  @Prop()
  interval: number;
}

export const SettingsSchema = SchemaFactory.createForClass(Settings);

export default model('settings', SettingsSchema);
