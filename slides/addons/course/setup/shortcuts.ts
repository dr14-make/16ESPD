import type { NavOperations, ShortcutOptions } from '@slidev/types'
import { presenterLayout } from '@slidev/client/state/storage.ts'
import { defineShortcutsSetup } from '@slidev/types'

// Slidev's own layout button cycles 1–3; `L` also reaches layout 4, styled in styles/index.css.
export default defineShortcutsSetup((_nav: NavOperations, base: ShortcutOptions[]) => [
  ...base,
  {
    name: 'cycle_presenter_layout',
    key: 'l',
    fn: () => { presenterLayout.value = presenterLayout.value % 4 + 1 },
  },
])
