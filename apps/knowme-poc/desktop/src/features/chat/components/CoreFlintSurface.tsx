// TJ-ARCH-MOB-001 compliant
import { registerBaseComponents, resolveFlintComponent, type A2uiComponentSpec } from '@flint/react'
import { useFlintSurface } from '../hooks/useFlintSurface'

registerBaseComponents()

function CoreComponent({ spec }: { spec: A2uiComponentSpec }) {
  const Component = resolveFlintComponent(spec.slug, {})
  if (!Component) return <div role="alert">Unknown A2UI component: {spec.slug}</div>
  return <Component {...spec.props}>{spec.children?.map((child) => <CoreComponent key={child.id} spec={child} />)}</Component>
}

export function CoreFlintSurface({ surfaceId }: { surfaceId: string }) {
  const { components } = useFlintSurface(surfaceId)
  return <section aria-label={`Generated surface ${surfaceId}`}>{components.map((spec) => <CoreComponent key={spec.id} spec={spec} />)}</section>
}
