## gorm
```go

// Don't use the fields that will be updated by gorm hook, such as UpdatedAt, CreateAt, DeletedAt.
// Because you don't know when gorm's hook will be executed. 
// 
// For example, 
// UpdateAt field int64, if you don't set gorm tag "autoUpdateTime:milli", it will be updated by seconds
// So, all fields related to CreateAt, UpdateAt, DeletedAt should be set to CreateAt, UpdateAt, DeleteAt. 
// Set time explicitly in the program logic, rather than relying on gorm's hook.
// Avoid conflicts with gorm's hook fields, so don't use gorm's hook fields, use your own fields instead

```