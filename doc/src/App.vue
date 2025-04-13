<script setup lang="ts">
import { useColorMode } from '@vueuse/core'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import CagelabConfig from './components/CagelabConfig.vue'

const mode = useColorMode()
mode.value = 'dark'
</script>

<template>
  <div class="flex justify-center items-center h-screen">
    <Card class=" w-2xl ">
      <CardHeader>
        <CardTitle>Cagelab configuration</CardTitle>
        <CardDescription>Please input your cage infomation</CardDescription>
      </CardHeader>
      <CardContent>
        <CagelabConfig />
      </CardContent>
    </Card>
  </div>
</template>
