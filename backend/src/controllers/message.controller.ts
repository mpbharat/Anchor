import type { Request, Response } from 'express';
import { z } from 'zod';
import * as messageService from '../services/message.service';

// POST /messages — append a voice turn. The AI layer supplies Anchor's reply;
// if the client only sends the user's turn, we persist it and echo it back.
export const addMessageSchema = z.object({
  role: z.enum(['user', 'anchor']).default('user'),
  content: z.string().min(1).max(10_000),
  turn_kind: z.enum(['commit', 'decline', 'checkin', 'chat']).optional(),
  reply: z
    .object({
      content: z.string().min(1).max(10_000),
      turn_kind: z.enum(['commit', 'decline', 'checkin', 'chat']).optional(),
    })
    .optional(),
});

export async function list(req: Request, res: Response): Promise<void> {
  res.json({ messages: await messageService.listMessages(req.user!.id) });
}

export async function add(req: Request, res: Response): Promise<void> {
  const { role, content, turn_kind, reply } = req.body;
  const message = await messageService.addMessage(req.user!.id, { role, content, turn_kind });
  let anchorReply = null;
  if (reply) {
    anchorReply = await messageService.addMessage(req.user!.id, {
      role: 'anchor',
      content: reply.content,
      turn_kind: reply.turn_kind,
    });
  }
  res.status(201).json({ message, reply: anchorReply });
}
