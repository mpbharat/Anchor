import { supabase } from '../config/supabase';

// messages (canonical): role user|anchor, content, turn_kind commit|decline|checkin|chat.
export interface Message {
  id: string;
  user_id: string;
  role: string;
  content: string;
  turn_kind: string | null;
  created_at: string;
}

export async function listMessages(userId: string, limit = 50): Promise<Message[]> {
  const { data, error } = await supabase
    .from('messages')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw new Error(error.message);
  return ((data ?? []) as Message[]).reverse();
}

export async function addMessage(
  userId: string,
  input: { role: 'user' | 'anchor'; content: string; turn_kind?: string },
): Promise<Message> {
  const { data, error } = await supabase
    .from('messages')
    .insert({
      user_id: userId,
      role: input.role,
      content: input.content,
      turn_kind: input.turn_kind ?? 'chat',
    })
    .select('*')
    .single();
  if (error) throw new Error(error.message);
  return data as Message;
}
