export abstract class AbstractDao<T extends { id: number }> {
  abstract onDestroy(): void
  abstract get(id: number): T | null
  abstract getAll(): T[]
  abstract create(item: Omit<T, 'id' | 'createdAt'>): T
  abstract delete(id: number): boolean
}
