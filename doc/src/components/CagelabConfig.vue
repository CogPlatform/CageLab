<script setup lang="ts">
import { Button } from '@/components/ui/button'
import {
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Switch } from '@/components/ui/switch'

import { useForm } from 'vee-validate'
import { CagelabConfigureSchema } from '@/schemas/cagelabConfigure'

import { useBomStore } from '@/stores/bom'
import type { CagelabConfigure } from '@/schemas/cagelabConfigure'

const bomStore = useBomStore()

const { isFieldDirty, handleSubmit } = useForm({
  validationSchema: CagelabConfigureSchema,
})

const onSubmit = handleSubmit((values) => {
  const config: CagelabConfigure = {
    name: values.name,
    width: values.width,
    height: values.height,
    core_length: values.core_length,
    extra_length: values.extra_length,

    type: values.type,
    need_adaptor: values.need_adaptor,
    need_extra_hook: values.need_extra_hook,
    adaptor_width: values.adaptor_width,
    adaptor_height: values.adaptor_height,
  }

  bomStore.setConfigure(config)
})
</script>

<template>
  <form class="space-y-6" @submit="onSubmit">
    <FormField v-slot="{ componentField }" name="width" :validate-on-blur="!isFieldDirty">
      <FormItem>
        <FormLabel>Width</FormLabel>
        <FormControl>
          <Input type="text" placeholder="width" v-bind="componentField" />
        </FormControl>
        <FormDescription> This is the width of your cage </FormDescription>
        <FormMessage />
      </FormItem>
    </FormField>

    <FormField v-slot="{ componentField }" name="height" :validate-on-blur="!isFieldDirty">
      <FormItem>
        <FormLabel>Height</FormLabel>
        <FormControl>
          <Input type="text" placeholder="heigth" v-bind="componentField" />
        </FormControl>
        <FormDescription> This is the height of your cage </FormDescription>
        <FormMessage />
      </FormItem>
    </FormField>

    <FormField v-slot="{ componentField }" name="core_length" :validate-on-blur="!isFieldDirty">
      <FormItem>
        <FormLabel>Core length</FormLabel>
        <FormControl>
          <Input type="text" placeholder="core length" v-bind="componentField" />
        </FormControl>
        <FormDescription> This is the core module length of your cagelab </FormDescription>
        <FormMessage />
      </FormItem>
    </FormField>

    <FormField v-slot="{ componentField }" name="extra_length" :validate-on-blur="!isFieldDirty">
      <FormItem>
        <FormLabel>extra length</FormLabel>
        <FormControl>
          <Input type="text" placeholder="extra length" v-bind="componentField" />
        </FormControl>
        <FormDescription> This is the extra module length of your cagelab </FormDescription>
        <FormMessage />
      </FormItem>
    </FormField>

    <FormField v-slot="{ value, handleChange }" name="need_adaptor">
      <FormItem class="flex flex-row items-center justify-between rounded-lg border p-4">
        <div class="space-y-0.5">
          <FormLabel class="text-base"> Need adaptor </FormLabel>
          <FormDescription> Do you need a adaptor for your cagelab </FormDescription>
        </div>
        <FormControl>
          <Switch :model-value="value" @update:model-value="handleChange" />
        </FormControl>
      </FormItem>
    </FormField>

    <div class="flex justify-between">
      <Button type="submit"> Submit </Button>
      <Button @click="bomStore.exportBom"> Download </Button>
    </div>
  </form>
</template>
