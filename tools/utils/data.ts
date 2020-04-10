export type Data<T extends { id: number, createdAt: Date | string }> = Omit<T, 'id' | 'createdAt'>
