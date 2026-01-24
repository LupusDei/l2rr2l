import phonicsBasics from './phonics-basics.json'
import cvcWords from './cvc-words.json'
import sightWords1 from './sight-words-1.json'
import sightWords2 from './sight-words-2.json'
import wordFamilyAt from './word-family-at.json'
import wordFamilyAn from './word-family-an.json'
import beginningBlends from './beginning-blends.json'
import endingBlends from './ending-blends.json'

import type { Lesson } from '../types/lesson'

export const seedLessons: Lesson[] = [
  phonicsBasics as Lesson,
  cvcWords as Lesson,
  sightWords1 as Lesson,
  sightWords2 as Lesson,
  wordFamilyAt as Lesson,
  wordFamilyAn as Lesson,
  beginningBlends as Lesson,
  endingBlends as Lesson,
]

export {
  phonicsBasics,
  cvcWords,
  sightWords1,
  sightWords2,
  wordFamilyAt,
  wordFamilyAn,
  beginningBlends,
  endingBlends,
}
