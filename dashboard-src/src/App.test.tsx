import { cleanup, fireEvent, render, screen, within } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

afterEach(cleanup);

vi.mock("./Chart", () => ({
  Chart: ({ onDateSelect }: { onDateSelect?: (date: string) => void }) => (
    <div data-testid="chart-fallback">
      График
      {onDateSelect ? <button onClick={() => onDateSelect("2026-08-25")}>Выбрать 25 августа</button> : null}
    </div>
  ),
}));

import { App } from "./App";
import { snapshot } from "./snapshot";

describe("Dashboard v2", () => {
  it("validates and loads the private v2 snapshot", () => {
    expect(snapshot.meta.contractVersion).toBe("2.0");
    expect(snapshot.meta.latestSourceDate).toBe("2026-08-30");
    expect(snapshot.days).toHaveLength(27);
  });

  it("provides semantic navigation, filters and table alternatives", () => {
    render(<App />);
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Дневник здоровья");
    expect(screen.getByRole("navigation", { name: "Основная навигация" })).toBeInTheDocument();
    const sevenDays = screen.getByRole("button", { name: "7 дней" });
    fireEvent.click(sevenDays);
    expect(sevenDays).toHaveAttribute("aria-pressed", "true");
    expect(screen.getByRole("table", { name: "Сводка по датам выбранного периода" })).toBeInTheDocument();
    expect(screen.getByRole("table", { name: "Калорийность и относительная позиция каждого дня" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Энергия по дням" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Макронутриенты без пересечения линий" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Что видно и что улучшить следующим" })).toBeInTheDocument();
    expect(screen.queryByText("Графики в прежнем виде")).not.toBeInTheDocument();
    expect(screen.queryByText("Линейный вид из предыдущей версии")).not.toBeInTheDocument();
    expect(screen.queryByText("Где аналитика сильна, а где осторожна")).not.toBeInTheDocument();
  });

  it("renders all five named design variants from the shared model", () => {
    const names = [
      "Операционный обзор",
      "Ночная лаборатория",
      "БЖУ-бенто",
      "Отчёт о восстановлении",
      "Консоль данных",
    ];
    names.forEach((name, index) => {
      const view = render(<App variantOverride={(index + 1) as 1 | 2 | 3 | 4 | 5} />);
      expect(screen.getByText(new RegExp(name))).toBeInTheDocument();
      view.unmount();
    });
  });

  it("opens the unified day drawer from the timeline", () => {
    render(<App />);
    fireEvent.click(screen.getAllByRole("button", { name: "Выбрать 25 августа" })[0]);
    const dialog = screen.getByRole("dialog");
    expect(within(dialog).getByText(/25 августа/i)).toBeInTheDocument();
    expect(within(dialog).getByRole("heading", { name: /Питание/i })).toBeInTheDocument();
    expect(within(dialog).getByRole("heading", { name: /Сон/i })).toBeInTheDocument();
    expect(within(dialog).getByRole("heading", { name: /Тренировки/i })).toBeInTheDocument();
    fireEvent.click(within(dialog).getByRole("button", { name: "Закрыть детали дня" }));
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
  });
});
