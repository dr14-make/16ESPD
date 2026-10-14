import { presenterLayout } from '@slidev/client/state/storage.ts'
import { defineAppSetup } from '@slidev/types'
import { watch } from 'vue'

// Slidev's layout button wraps from 3 back to 1; step through layout 4 on the way.
export default defineAppSetup(() => {
  watch(presenterLayout, (now, before) => {
    if (before === 3 && now === 1)
      presenterLayout.value = 4
  })
})
