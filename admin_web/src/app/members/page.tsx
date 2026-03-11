"use client";

import React, { useEffect, useState } from "react";
import { collection, onSnapshot, query, updateDoc, doc } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { User, Droplet, Flame, CheckCircle, AlertCircle } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";

export default function MembersPage() {
  const [users, setUsers] = useState<any[]>([]);
  const [nudges, setNudges] = useState<Record<string, any[]>>({});
  const [loading, setLoading] = useState(true);

  // Dialog State
  const [selectedUser, setSelectedUser] = useState<any | null>(null);
  const [targetCalories, setTargetCalories] = useState("");
  const [targetWater, setTargetWater] = useState("");
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, "users"), (snapshot) => {
      const usersData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setUsers(usersData);
      setLoading(false);
    });

    const unsubNudges = onSnapshot(collection(db, "nudges"), (snapshot) => {
      const nudgeMap: Record<string, any[]> = {};
      snapshot.forEach(docSnap => {
        const data = docSnap.data();
        if (data.clientId) {
          if (!nudgeMap[data.clientId]) nudgeMap[data.clientId] = [];
          nudgeMap[data.clientId].push({ id: docSnap.id, ...data });
        }
      });
      setNudges(nudgeMap);
    });

    return () => {
      unsub();
      unsubNudges();
    };
  }, []);

  const approveUser = async (userId: string) => {
    try {
      // Update users collection (admin web reads this for status badge)
      await updateDoc(doc(db, "users", userId), { status: "active" });
      // Mirror to clients collection (Flutter reads subscriptionStatus from here)
      await updateDoc(doc(db, "clients", userId), { subscriptionStatus: "active" }).catch(() => {
        // clients doc may not exist yet if user hasn't completed onboarding — that's ok
      });
    } catch (e) {
      console.error(e);
    }
  };

  const rejectUser = async (userId: string) => {
    try {
      // Update users collection (admin web reads this for status badge)
      await updateDoc(doc(db, "users", userId), { status: "rejected" });
      // Mirror to clients collection (Flutter reads subscriptionStatus from here)
      await updateDoc(doc(db, "clients", userId), { subscriptionStatus: "rejected" }).catch(() => {
        // clients doc may not exist yet — that's ok
      });
    } catch (e) {
      console.error(e);
    }
  };

  const openClientDetails = (user: any) => {
    setSelectedUser(user);
    setTargetCalories(user.targetCalories?.toString() || "");
    setTargetWater(user.targetWater?.toString() || "");
  };

  const saveClientTargets = async () => {
    if (!selectedUser) return;
    setUpdating(true);
    try {
      // 1. Update users collection (admin web reads targetCalories/targetWater from here)
      await updateDoc(doc(db, "users", selectedUser.id), {
        targetCalories: Number(targetCalories),
        targetWater: Number(targetWater),
      });

      // 2. Mirror to clients collection with Flutter-compatible field names
      //    Flutter reads targetCalories and targetWaterMl from clients/{uid}
      await updateDoc(doc(db, "clients", selectedUser.id), {
        targetCalories: Number(targetCalories),
        targetWaterMl: Number(targetWater),   // Flutter uses targetWaterMl (not targetWater)
      }).catch(() => {
        // clients doc may not exist yet if user hasn't completed onboarding — that's ok
      });

      // 3. Resolve all pending nudges for this user
      //    Set both resolved (admin web) and status (Flutter) so both sides see it resolved
      const userNudges = nudges[selectedUser.id] || [];
      for (const nudge of userNudges) {
        await updateDoc(doc(db, "nudges", nudge.id), {
          resolved: true,
          status: "resolved",   // Flutter checks status field
        });
      }

      setSelectedUser(null);
    } catch (error) {
      console.error("Error updating targets:", error);
    } finally {
      setUpdating(false);
    }
  };

  if (loading) {
    return <div className="p-8">Loading...</div>;
  }

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Client Management</h1>
          <p className="text-gray-500">View and manage all your signed up users, subscriptions, and nudges.</p>
        </div>
      </div>

      <div className="border rounded-md">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Email</TableHead>
              <TableHead>Account Status</TableHead>
              <TableHead>Subscription</TableHead>
              <TableHead>Nudges</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {users.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center h-24">
                  No clients found.
                </TableCell>
              </TableRow>
            ) : (
              users.map((user) => (
                <TableRow key={user.id}>
                  <TableCell className="font-medium">
                    {user.displayName || user.name || "Unknown"}
                  </TableCell>
                  <TableCell>{user.email}</TableCell>
                  <TableCell>
                    <Badge variant={user.status === 'active' ? 'outline' : 'secondary'} className={
                      user.status === 'active' ? 'bg-green-50 text-green-700 border-green-200' :
                      user.status === 'pending' ? 'bg-yellow-50 text-yellow-700 border-yellow-200' :
                      'bg-red-50 text-red-700 border-red-200'
                    }>
                      {user.status || 'pending'}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline" className={
                      user.subscriptionStatus === 'active' ? 'bg-blue-50 text-blue-700 border-blue-200' : 'bg-gray-50 text-gray-700'
                    }>
                      {user.subscriptionStatus || 'none'}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    {(() => {
                      const pending = (nudges[user.id] || []).filter(
                        (n: any) => !n.resolved && n.status !== "resolved"
                      );
                      return pending.length > 0 ? (
                        <Badge variant="destructive" className="bg-red-50 text-red-700 border-red-200">
                          {pending.length} pending
                        </Badge>
                      ) : (
                        <span className="text-sm text-gray-400">0 pending</span>
                      );
                    })()}
                  </TableCell>
                  <TableCell className="text-right">
                    {user.status === 'pending' ? (
                      <div className="flex justify-end gap-2">
                        <Button size="sm" onClick={() => approveUser(user.id)} className="bg-green-600 hover:bg-green-700 text-white">Approve</Button>
                        <Button size="sm" variant="destructive" onClick={() => rejectUser(user.id)}>Reject</Button>
                      </div>
                    ) : (
                      <Button size="sm" variant="outline" onClick={() => openClientDetails(user)}>Manage</Button>
                    )}
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      <Dialog open={!!selectedUser} onOpenChange={(open) => !open && setSelectedUser(null)}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Manage Client</DialogTitle>
            <DialogDescription>
              Update {selectedUser?.displayName || 'this client'}'s daily targets.
            </DialogDescription>
          </DialogHeader>
          
          <div className="grid gap-4 py-4">
            {nudges[selectedUser?.id] && nudges[selectedUser?.id].filter(
              (n: any) => !n.resolved && n.status !== "resolved"
            ).length > 0 && (
              <div className="bg-red-50 border border-red-200 text-red-800 p-3 rounded-md flex items-start gap-3">
                <AlertCircle className="w-5 h-5 text-red-600 mt-0.5 shrink-0" />
                <div>
                  <p className="font-semibold text-sm">Action Required</p>
                  <p className="text-sm">
                    Client requested updates for: {nudges[selectedUser?.id]
                      .filter((n: any) => !n.resolved && n.status !== "resolved")
                      .map((n: any) => n.type)
                      .join(", ")}
                  </p>
                </div>
              </div>
            )}

            <div className="grid grid-cols-4 items-center gap-4">
              <label htmlFor="calories" className="text-right text-sm font-medium">
                <Flame className="w-4 h-4 inline mr-2 text-orange-500" />
                Calories
              </label>
              <Input
                id="calories"
                type="number"
                value={targetCalories}
                onChange={(e) => setTargetCalories(e.target.value)}
                className="col-span-3"
                placeholder="e.g. 2000"
              />
            </div>
            
            <div className="grid grid-cols-4 items-center gap-4">
              <label htmlFor="water" className="text-right text-sm font-medium">
                <Droplet className="w-4 h-4 inline mr-2 text-blue-500" />
                Water (ml)
              </label>
              <Input
                id="water"
                type="number"
                value={targetWater}
                onChange={(e) => setTargetWater(e.target.value)}
                className="col-span-3"
                placeholder="e.g. 3000"
              />
            </div>
          </div>
          
          <div className="flex justify-end">
            <Button onClick={saveClientTargets} disabled={updating}>
              {updating ? "Saving..." : "Save Changes & Resolve Nudges"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
