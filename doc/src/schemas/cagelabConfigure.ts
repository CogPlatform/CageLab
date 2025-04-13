import { toTypedSchema } from '@vee-validate/zod'
import z from 'zod'

const config = z.object({
  // name of cagelab configuration
  name: z.string().default('cagelab'),

  // width of cagelab
  width: z.coerce
    .number({ message: 'Width must be a number' })
    .positive({ message: 'Width must be positive' })
    .int({ message: 'Width must be an integer' })
    .min(270, { message: 'Width must be at least 270' })
    .default(270),

  // height of cagelab
  height: z.coerce
    .number({ message: 'Height must be a number' })
    .positive({ message: 'Height must be positive' })
    .int({ message: 'Height must be an integer' })
    .min(300, { message: 'Height must be at least 300' })
    .default(300),

  // length of core module
  core_length: z.coerce
    .number({ message: 'Core length must be a number' })
    .positive({ message: 'Core length must be positive' })
    .int({ message: 'Core length must be an integer' })
    .min(120, { message: 'Core length must be at least 120' })
    .default(120),

  // length of extra module
  extra_length: z.coerce
    .number({ message: 'Extra length must be a number' })
    .positive({ message: 'Extra length must be positive' })
    .int({ message: 'Extra length must be an integer' })
    .min(120, { message: 'Extra length must be at least 120' })
    .default(120),

  // type of control
  type: z.enum(['touch', 'joystick']).default('touch'),

  // whether need adaptor
  need_adaptor: z.boolean().default(false),
  // width of adaptor
  adaptor_width: z.coerce
    .number({ message: 'Adaptor width must be a number' })
    .positive({ message: 'Adaptor width must be positive' })
    .int({ message: 'Adaptor width must be an integer' })
    .default(10),
  // height of adaptor
  adaptor_height: z.coerce
    .number({ message: 'Adaptor height must be a number' })
    .positive({ message: 'Adaptor height must be positive' })
    .int({ message: 'Adaptor height must be an integer' })
    .default(10),

  // whether need extra hook
  need_extra_hook: z.boolean().default(false),
})

const CagelabConfigureSchema = toTypedSchema(config)

type CagelabConfigure = z.infer<typeof config>

export type { CagelabConfigure }
export { CagelabConfigureSchema }
