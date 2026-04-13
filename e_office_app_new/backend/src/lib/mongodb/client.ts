import mongoose from 'mongoose';

export async function connectMongoDB(): Promise<typeof mongoose> {
  const uri = process.env.MONGODB_URI || '';
  return mongoose.connect(uri, { dbName: 'qlvb_logs' });
}
