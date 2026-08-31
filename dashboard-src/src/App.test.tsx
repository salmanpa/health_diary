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

  it("opens the unified day drawer from the timeline", () => {
    render(<App />);
    fireEvent.click(screen.getAllByRole("button", { name: "Выбрать 25 августа" })[0]);
    const dialog = screen.getByRole("dialog");
    expect(within(dialog).getByText(/25 августа/i)).toBeInTheDocument();
    expect(within(dialog).getByRole("heading", { name: /Питание/i })).toBeInTheDocument();
    expect(within(dialog).getByText("4 приёма пищи")).toBeInTheDocument();
    expect(within(dialog).getByRole("heading", { name: "Завтрак" })).toBeInTheDocument();
    expect(within(dialog).getByRole("heading", { name: "Обед" })).toBeInTheDocument();
    expect(within(dialog).getByRole("heading", { name: "Ужин" })).toBeInTheDocument();
    expect(within(dialog).getByRole("heading", { name: "Перекусы" })).toBeInTheDocument();
    expect(within(dialog).getByRole("heading", { name: /Сон/i })).toBeInTheDocument();
    expect(within(dialog).getByRole("heading", { name: /Тренировки/i })).toBeInTheDocument();
    expect(within(dialog).queryByLabelText("Правила подсветки БЖУ блюда")).not.toBeInTheDocument();
    expect(document.querySelectorAll(".protein-highlight").length).toBeGreaterThan(0);
    expect(document.querySelectorAll(".fat-highlight").length).toBeGreaterThan(0);
    expect(document.querySelectorAll(".carbs-highlight").length).toBeGreaterThan(0);
    fireEvent.click(within(dialog).getByRole("button", { name: "Закрыть детали дня" }));
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();

    fireEvent.click(screen.getAllByRole("button", { name: "Открыть детали среда, 26 августа" })[0]);
    expect(document.querySelectorAll(".energy-highlight").length).toBeGreaterThan(0);
  });
});
