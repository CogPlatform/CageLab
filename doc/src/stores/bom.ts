import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { type CagelabConfigure } from '@/schemas/cagelabConfigure'
import Papa from 'papaparse'

interface aluminumProfile {
  name: string
  param: string
  length: number
  quantity: number
}

export const useBomStore = defineStore('bom', () => {
  const configure = ref<CagelabConfigure>({
    name: 'cagelab',
    width: 0,
    height: 0,
    core_length: 0,
    extra_length: 0,

    type: 'touch',
    need_adaptor: false,
    need_extra_hook: true,
    adaptor_width: 0,
    adaptor_height: 0,
  })

  function setConfigure(config: CagelabConfigure) {
    configure.value = config
    console.log(config)
  }

  const framework = computed(() => {
    const framework_bom: aluminumProfile[] = []

    const frame_width: aluminumProfile = {
      name: '框架横梁',
      param: `TXCJ-H6-6-2020-L${configure.value.width}-DA6`,
      length: configure.value.width,
      quantity: 6,
    }

    const frame_height: aluminumProfile = {
      name: '框架立柱',
      param: `TXCJ-H6-6-2020-L${configure.value.height}-DA6-LC-Z6-A10-RC-Z6-A10`,
      length: configure.value.height,
      quantity: 6,
    }

    const frame_core_lenght: aluminumProfile = {
      name: '框架核心纵梁',
      param: `TXCJ-H6-6-2040-L${configure.value.core_length}-DA6`,
      length: configure.value.core_length,
      quantity: 2,
    }

    const frame_extra_lenght: aluminumProfile = {
      name: '框架拓展纵梁',
      param: `TXCJ-H6-6-2040-L${configure.value.extra_length}-DA6`,
      length: configure.value.extra_length,
      quantity: 2,
    }

    framework_bom.push(frame_width, frame_height, frame_core_lenght, frame_extra_lenght)

    if (configure.value.need_adaptor) {
      const frame_adapter_width: aluminumProfile = {
        name: '框架适配横梁',
        param: `TXCJ-H6-6-2020-L${configure.value.adaptor_width}-DA6`,
        length: configure.value.adaptor_width,
        quantity: 2,
      }

      const frame_adapter_height: aluminumProfile = {
        name: '框架适配立柱',
        param: `TXCJ-H6-6-2020-L${configure.value.adaptor_height}-DA6`,
        length: configure.value.adaptor_height,
        quantity: 2,
      }

      framework_bom.push(frame_adapter_width, frame_adapter_height)
    }

    if (configure.value.need_extra_hook) {
      const frame_hook_width: aluminumProfile = {
        name: '框架拓展挂钩横梁',
        param: `TXCJ-H6-6-2020-L${configure.value.width + 40}-DA6-LC-Z6-A10-RC-Z6-A10`,
        length: configure.value.width + 40,
        quantity: 1,
      }

      const frame_hook_height: aluminumProfile = {
        name: '框架拓展挂钩立柱',
        param: `TXCJ-H6-6-2020-L${configure.value.height}-DA6`,
        length: configure.value.height,
        quantity: 1,
      }

      framework_bom.push(frame_hook_width, frame_hook_height)
    }

    return {
      framework_bom,
    }
  })

  function exportBom() {
    const data = framework.value.framework_bom

    const csv = Papa.unparse(data)

    console.log(csv)

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    if (link.download !== undefined) {
      // Browsers that support HTML5 download attribute
      const url = URL.createObjectURL(blob)
      link.href = url
      link.download = 'framework_bom.csv'
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      URL.revokeObjectURL(url)
    }
  }

  return {
    configure,
    framework,
    setConfigure,
    exportBom,
  }
})
