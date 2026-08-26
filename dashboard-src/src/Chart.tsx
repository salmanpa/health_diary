import { useEffect, useRef } from "react";
import * as echarts from "echarts/core";
import { BarChart, HeatmapChart, LineChart } from "echarts/charts";
import {
  AriaComponent,
  DataZoomComponent,
  GridComponent,
  LegendComponent,
  TooltipComponent,
  VisualMapComponent,
} from "echarts/components";
import { SVGRenderer } from "echarts/renderers";
import type { EChartsCoreOption } from "echarts/core";

echarts.use([
  LineChart, BarChart, HeatmapChart, GridComponent, TooltipComponent,
  LegendComponent, DataZoomComponent, VisualMapComponent, AriaComponent, SVGRenderer,
]);

interface ChartProps {
  option: EChartsCoreOption;
  className?: string;
  onDateSelect?: (date: string) => void;
}

export function Chart({ option, className = "chart", onDateSelect }: ChartProps) {
  const elementRef = useRef<HTMLDivElement>(null);
  const handlerRef = useRef(onDateSelect);
  handlerRef.current = onDateSelect;

  useEffect(() => {
    if (!elementRef.current) return;
    const instance = echarts.init(elementRef.current, undefined, { renderer: "svg" });
    instance.setOption(option, { notMerge: true });
    instance.on("click", (params: unknown) => {
      const candidate = params as { name?: unknown; value?: unknown };
      const date = typeof candidate.name === "string"
        ? candidate.name
        : Array.isArray(candidate.value) && typeof candidate.value[0] === "string"
          ? candidate.value[0]
          : null;
      if (date && /^\d{4}-\d{2}-\d{2}$/.test(date)) handlerRef.current?.(date);
    });
    const observer = new ResizeObserver(() => instance.resize());
    observer.observe(elementRef.current);
    return () => {
      observer.disconnect();
      instance.dispose();
    };
  }, []);

  useEffect(() => {
    const instance = elementRef.current ? echarts.getInstanceByDom(elementRef.current) : null;
    instance?.setOption(option, { notMerge: true });
  }, [option]);

  return <div ref={elementRef} className={className} />;
}
