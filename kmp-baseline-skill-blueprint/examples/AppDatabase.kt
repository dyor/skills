package org.example.project.data.room

import androidx.room.ConstructFrom
import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.RoomDatabaseConstructor

@Database(entities = [Script::class], version = 1)
@ConstructFrom(AppDatabaseConstructor::class)
abstract class AppDatabase : RoomDatabase(), DB {
    abstract fun scriptDao(): ScriptDao

    override fun clearAllTables() {}
}

// Added to allow for easy mocking/testing if needed and sharing between iOS/Android
interface DB {
    fun clearAllTables() {}
}

@Suppress("NO_ACTUAL_FOR_EXPECT", "EXPECT_ACTUAL_CLASSIFIERS_ARE_IN_BETA_WARNING")
expect object AppDatabaseConstructor : RoomDatabaseConstructor<AppDatabase> {
    override fun initialize(): AppDatabase
}