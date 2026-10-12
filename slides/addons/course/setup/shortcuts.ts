import type { NavOperations, ShortcutOptions } from '@slidev/types'
import { presenterLayout } from '@slidev/client/state/storage.ts'
import { defineShortcutsSetup } from '@slidev/types'

// `L` cycles all four presenter layouts from the keyboard; layout 4 is styled in styles/index.css.
export default defineShortcutsSetup((_nav: NavOperations, base: ShortcutOptions[]) => [
  ...base,
  {
    name: 'cycle_presenter_layout',
    key: 'l',
    fn: () => { presenterLayout.value = presenterLayout.value % 4 + 1 },
  },
])
