package org.example.project.domain

import android.content.Context
import androidx.room.Room
import androidx.room.RoomDatabase

fun getDatabaseBuilder(context: Context): RoomDatabase.Builder<AppDatabase> {
    val appContext = context.applicationContext
    val dbFile = appContext.getDatabasePath("factory.db")
    return Room.databaseBuilder(
        context = appContext,
        klass = AppDatabase::class.java,
        name = dbFile.absolutePath
    )
}