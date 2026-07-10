import { describe, it, expect } from '@ohos/hypium';
import {
  getUserLevel,
  getUserLevelLabel,
  getDaysToNextLevel
} from '../main/ets/domain/rules/UserLevelRules';

/**
 * 用户等级规则单元测试
 */

export default function userLevelTest() {

  describe('UserLevel_GetUserLevel', () => {
    it('zeroDays_returnsLevel1', 0, () => {
      expect(getUserLevel(0)).assertEqual(1);
    });

    it('twoDays_returnsLevel1', 0, () => {
      expect(getUserLevel(2)).assertEqual(1);
    });

    it('threeDays_returnsLevel2', 0, () => {
      expect(getUserLevel(3)).assertEqual(2);
    });

    it('sixDays_returnsLevel2', 0, () => {
      expect(getUserLevel(6)).assertEqual(2);
    });

    it('sevenDays_returnsLevel3', 0, () => {
      expect(getUserLevel(7)).assertEqual(3);
    });

    it('twentyNineDays_returnsLevel3', 0, () => {
      expect(getUserLevel(29)).assertEqual(3);
    });

    it('thirtyDays_returnsLevel4', 0, () => {
      expect(getUserLevel(30)).assertEqual(4);
    });

    it('fortyNineDays_returnsLevel4', 0, () => {
      expect(getUserLevel(49)).assertEqual(4);
    });

    it('fiftyDays_returnsLevel5', 0, () => {
      expect(getUserLevel(50)).assertEqual(5);
    });

    it('seventyTwoDays_returnsLevel5', 0, () => {
      expect(getUserLevel(72)).assertEqual(5);
    });

    it('seventyThreeDays_returnsLevel6', 0, () => {
      expect(getUserLevel(73)).assertEqual(6);
    });

    it('ninetyEightDays_returnsLevel6', 0, () => {
      expect(getUserLevel(98)).assertEqual(6);
    });

    it('ninetyNineDays_returnsLevel7', 0, () => {
      expect(getUserLevel(99)).assertEqual(7);
    });

    it('oneHundredDays_returnsLevel7', 0, () => {
      expect(getUserLevel(100)).assertEqual(7);
    });
  });

  describe('UserLevel_GetUserLevelLabel', () => {
    it('zeroDays_returnsLV1', 0, () => {
      expect(getUserLevelLabel(0)).assertEqual('LV.1');
    });

    it('sevenDays_returnsLV3', 0, () => {
      expect(getUserLevelLabel(7)).assertEqual('LV.3');
    });

    it('ninetyNineDays_returnsLV7', 0, () => {
      expect(getUserLevelLabel(99)).assertEqual('LV.7');
    });
  });

  describe('UserLevel_GetDaysToNextLevel', () => {
    it('zeroDays_needs3Days', 0, () => {
      expect(getDaysToNextLevel(0)).assertEqual(3);
    });

    it('twoDays_needs1Day', 0, () => {
      expect(getDaysToNextLevel(2)).assertEqual(1);
    });

    it('sevenDays_needs23Days', 0, () => {
      expect(getDaysToNextLevel(7)).assertEqual(23);
    });

    it('ninetyNineDays_returnsNull', 0, () => {
      expect(getDaysToNextLevel(99)).assertNull();
    });

    it('oneHundredDays_returnsNull', 0, () => {
      expect(getDaysToNextLevel(100)).assertNull();
    });
  });
}
