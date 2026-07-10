import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { HomeStore, HomeStoreDeps } from '../main/ets/viewmodel/HomeStore';
import { createDefaultTaskInfoList } from '../main/ets/domain/constants/TaskCatalog';
import { getToday, getDateOffset, getMonthGrid, getYearMonth, getMonthOffset } from '../main/ets/domain/utils/DateUtils';
import { DayInfo } from '../main/ets/domain/models/DayInfo';
import {
  FakeTaskRepo,
  FakeDayInfoRepo,
  FakeDayTaskRepo,
  FakePrefRepo,
  FakeFormService,
  FakeRecoveryRepo
} from './fakes/FakeRepositories';

/**
 * 月视图跨月浏览单元测试
 * 验证：打开月视图加载当前月、上一月/下一月切换、浏览不影响 selectedDate、点击日期选中并返回
 */

const TODAY: string = getToday();

function makeDeps(): HomeStoreDeps {
  return new HomeStoreDeps(
    new FakeTaskRepo(),
    new FakeDayInfoRepo(),
    new FakeDayTaskRepo(),
    new FakePrefRepo(),
    new FakeFormService(),
    new FakeRecoveryRepo()
  );
}

function makeDefaultStore(deps: HomeStoreDeps): HomeStore {
  const store = HomeStore.createForTest(deps);
  (deps.taskRepo as FakeTaskRepo).seed(createDefaultTaskInfoList());
  return store;
}

export default function monthViewTest() {

  describe('MonthView_OpenLoadsCurrentMonth', () => {
    it('openMonthView_setsMonthViewDateToSelectedDate', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();

      await store.openMonthView();
      expect(store.isMonthView).assertTrue();
      expect(store.monthViewDate).assertEqual(store.selectedDate);
    });

    it('openMonthView_loadsMonthGridData', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      await store.enableTask(3); // 微笑

      const task = store.dayTasks.find(t => t.taskId === 3);
      if (task) {
        await store.checkin(task.id);
      }

      await store.openMonthView();
      // 今天的完成状态应为 3（全部完成）
      const status = store.monthViewData.get(TODAY) ?? 0;
      expect(status).assertEqual(3);
    });

    it('openMonthView_monthViewDataCoversGridRange', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();

      await store.openMonthView();
      const grid = getMonthGrid(store.selectedDate);
      // 网格中每个日期都应在 monthViewData 中有条目
      for (const date of grid) {
        expect(store.monthViewData.has(date)).assertTrue();
      }
    });
  });

  describe('MonthView_CrossMonthNavigation', () => {
    it('loadPreviousMonth_updatesMonthViewDate', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      await store.openMonthView();

      const beforeDate = store.monthViewDate;
      await store.loadPreviousMonth();
      const afterDate = store.monthViewDate;

      // monthViewDate 应变为上个月同一天
      expect(afterDate).assertEqual(getMonthOffset(beforeDate, -1));
    });

    it('loadNextMonth_updatesMonthViewDate', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      await store.openMonthView();

      const beforeDate = store.monthViewDate;
      await store.loadNextMonth();
      const afterDate = store.monthViewDate;

      expect(afterDate).assertEqual(getMonthOffset(beforeDate, 1));
    });

    it('loadPreviousMonth_monthViewDataCoversNewGridRange', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      await store.openMonthView();

      await store.loadPreviousMonth();
      const grid = getMonthGrid(store.monthViewDate);
      for (const date of grid) {
        expect(store.monthViewData.has(date)).assertTrue();
      }
      // 新月份的网格日期应与之前不同
      const originalGrid = getMonthGrid(TODAY);
      expect(grid[0] !== originalGrid[0]).assertTrue();
    });

    it('crossMonth_doesNotChangeSelectedDate', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      const originalSelected = store.selectedDate;

      await store.openMonthView();
      await store.loadPreviousMonth();
      expect(store.selectedDate).assertEqual(originalSelected);

      await store.loadNextMonth();
      expect(store.selectedDate).assertEqual(originalSelected);

      await store.loadNextMonth();
      expect(store.selectedDate).assertEqual(originalSelected);
    });

    it('crossMonth_monthViewDateYearMonthChanges', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      await store.openMonthView();

      const originalYM = getYearMonth(store.monthViewDate);
      await store.loadPreviousMonth();
      const prevYM = getYearMonth(store.monthViewDate);
      expect(prevYM !== originalYM).assertTrue();

      await store.loadNextMonth();
      const backYM = getYearMonth(store.monthViewDate);
      expect(backYM).assertEqual(originalYM);
    });

    it('crossMonth_loadsHistoricalDayInfo', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();

      // 插入一个历史月份的 DayInfo（上个月 15 号，全部完成）
      const lastMonth15 = getMonthOffset(TODAY, -1).substring(0, 6) + '15';
      await deps.dayRepo.upsertDayInfo(new DayInfo(lastMonth15, 2, 2));

      await store.openMonthView();
      await store.loadPreviousMonth();

      // 上个月 15 号应为全部完成状态
      const status = store.monthViewData.get(lastMonth15) ?? 0;
      expect(status).assertEqual(3);
    });
  });

  describe('MonthView_SelectDateFromMonthView', () => {
    it('selectDateFromMonthView_updatesSelectedDate', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      await store.openMonthView();

      // 浏览到上个月
      await store.loadPreviousMonth();
      const browseDate = store.monthViewDate;
      expect(store.selectedDate !== browseDate).assertTrue();

      // 点击上个月的第一天
      const grid = getMonthGrid(store.monthViewDate);
      const targetDate = grid[10]; // 网格中间附近某个日期
      await store.selectDateFromMonthView(targetDate);

      expect(store.isMonthView).assertFalse();
      expect(store.selectedDate).assertEqual(targetDate);
    });

    it('selectDateFromMonthView_afterBrowsingDifferentMonth', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      const originalSelected = store.selectedDate;

      await store.openMonthView();
      // 浏览两个月后
      await store.loadPreviousMonth();
      await store.loadPreviousMonth();

      // 选中当前浏览月份的一个日期
      const grid = getMonthGrid(store.monthViewDate);
      const targetDate = grid[14];
      await store.selectDateFromMonthView(targetDate);

      expect(store.selectedDate).assertEqual(targetDate);
      expect(store.selectedDate !== originalSelected).assertTrue();
      // dayTasks 应已加载
      expect(store.dayTasks !== null).assertTrue();
    });

    it('selectDateFromMonthView_closesMonthView', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      await store.openMonthView();

      const grid = getMonthGrid(store.monthViewDate);
      await store.selectDateFromMonthView(grid[0]);

      expect(store.isMonthView).assertFalse();
    });
  });

  describe('MonthView_CloseMonthView', () => {
    it('closeMonthView_doesNotChangeSelectedDate', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      const originalSelected = store.selectedDate;

      await store.openMonthView();
      await store.loadPreviousMonth();
      store.closeMonthView();

      expect(store.isMonthView).assertFalse();
      expect(store.selectedDate).assertEqual(originalSelected);
    });
  });

  describe('MonthView_GetMonthOffsetBoundary', () => {
    it('monthEnd_jan31_backOne_staysInFeb', 0, () => {
      // 1月31日 -1 月 → 2月28日（clamp 到月末）
      const result = getMonthOffset('20260131', -1);
      expect(result).assertEqual('20251228');
    });

    it('monthEnd_mar31_backOne_staysInFeb', 0, () => {
      // 3月31日 -1 月 → 2月28日（不是3月3日）
      const result = getMonthOffset('20260331', -1);
      expect(result).assertEqual('20260228');
    });

    it('monthEnd_mar31_forwardOne_clampsToApr30', 0, () => {
      // 3月31日 +1 月 → 4月30日（clamp 到月末）
      const result = getMonthOffset('20260331', 1);
      expect(result).assertEqual('20260430');
    });

    it('monthEnd_jan31_forwardOne_clampsToFeb28', 0, () => {
      // 1月31日 +1 月 → 2月28日
      const result = getMonthOffset('20260131', 1);
      expect(result).assertEqual('20260228');
    });

    it('monthEnd_dec31_backOne_staysInNov30', 0, () => {
      // 12月31日 -1 月 → 11月30日
      const result = getMonthOffset('20261231', -1);
      expect(result).assertEqual('20261130');
    });

    it('leapYear_feb29_forwardOne_clampsToMar29', 0, () => {
      // 2028 是闰年，2月29日 +1 月 → 3月29日
      const result = getMonthOffset('20280229', 1);
      expect(result).assertEqual('20280329');
    });

    it('normalDay_mar15_backOne_isFeb15', 0, () => {
      // 普通日期不触发 clamp
      const result = getMonthOffset('20260315', -1);
      expect(result).assertEqual('20260215');
    });

    it('loadPreviousMonth_fromMonthEnd_clampsToPrevMonth', 0, async () => {
      // 模拟选中 3 月 31 日，验证上一月不会溢出回 3 月
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      // 直接设置 monthViewDate 到 3 月 31 日
      store.monthViewDate = '20260331';
      store.isMonthView = true;

      await store.loadPreviousMonth();
      // 应到 2 月，而不是溢出到 3 月
      expect(getYearMonth(store.monthViewDate)).assertEqual('202602');
      // 确认日份不超 28
      const day = parseInt(store.monthViewDate.substring(6, 8), 10);
      expect(day <= 28).assertTrue();
    });
  });
}
