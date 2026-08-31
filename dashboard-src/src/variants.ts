export type DashboardVariantId = 1 | 2 | 3 | 4 | 5;

export interface DashboardVariant {
  id: DashboardVariantId;
  code: string;
  name: string;
  descriptor: string;
  feature: "operations" | "night-lab" | "macro-bento" | "recovery-report" | "data-console";
  chart: {
    ink: string;
    muted: string;
    grid: string;
    green: string;
    blue: string;
    violet: string;
    amber: string;
    red: string;
    surface: string;
  };
}

export const DASHBOARD_VARIANTS: Record<DashboardVariantId, DashboardVariant> = {
  1: {
    id: 1,
    code: "01 / 05",
    name: "Операционный обзор",
    descriptor: "Компактные показатели и малые графики",
    feature: "operations",
    chart: { ink: "#17231e", muted: "#66736c", grid: "#dce4df", green: "#17785b", blue: "#326f9d", violet: "#7462a4", amber: "#aa701e", red: "#b64e45", surface: "#ffffff" },
  },
  2: {
    id: 2,
    code: "02 / 05",
    name: "Ночная лаборатория",
    descriptor: "Контрастная лента месяца и сигналы",
    feature: "night-lab",
    chart: { ink: "#eef6f3", muted: "#9cacb2", grid: "#2d4148", green: "#57d6a4", blue: "#63aef1", violet: "#b69af4", amber: "#efb85b", red: "#ff7b70", surface: "#122026" },
  },
  3: {
    id: 3,
    code: "03 / 05",
    name: "БЖУ-бенто",
    descriptor: "Питание в центре, тёплая карточная сетка",
    feature: "macro-bento",
    chart: { ink: "#342c24", muted: "#786d62", grid: "#e8ded1", green: "#28785f", blue: "#49799f", violet: "#856a9e", amber: "#c47a32", red: "#b95048", surface: "#fffaf2" },
  },
  4: {
    id: 4,
    code: "04 / 05",
    name: "Отчёт о восстановлении",
    descriptor: "Редакционная подача сна и нагрузки",
    feature: "recovery-report",
    chart: { ink: "#171717", muted: "#6d6d6d", grid: "#dedede", green: "#08755b", blue: "#205b8d", violet: "#76528e", amber: "#a86518", red: "#a83e37", surface: "#ffffff" },
  },
  5: {
    id: 5,
    code: "05 / 05",
    name: "Консоль данных",
    descriptor: "Плотный тёмный интерфейс для проверки дней",
    feature: "data-console",
    chart: { ink: "#e8f5ee", muted: "#8ba097", grid: "#263b32", green: "#4ddb93", blue: "#62a8ee", violet: "#b18de6", amber: "#efbd5b", red: "#ff766c", surface: "#0f1915" },
  },
};

export function dashboardVariantFromMode(mode: string): DashboardVariantId {
  const match = mode.match(/variant-([1-5])$/);
  return match ? Number(match[1]) as DashboardVariantId : 1;
}

export const DEFAULT_DASHBOARD_VARIANT = dashboardVariantFromMode(import.meta.env.MODE);
