# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that could not be resolved. If any packages are flagged as incompatible, check NuGet for updated versions that support your target framework.

## 3. Build the Solution

Perform a clean build to confirm no errors surface during compilation:

```bash
dotnet clean
dotnet build --configuration Release
```

Review all warnings in the build output. While warnings do not block compilation, some may indicate deprecated APIs or platform-specific code paths that could cause runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may point to behavioral differences between .NET Framework and modern .NET, such as changes in:
- `System.Data` behavior
- ADO.NET provider availability
- Connection string handling

## 5. Validate ADO.NET Provider Availability

Since the project is named `AdoCore`, it likely relies on ADO.NET database providers. Confirm that the database provider NuGet package you depend on is explicitly referenced in the `.csproj` file and is compatible with your target framework. Common providers include:

| Database | Package |
|---|---|
| SQL Server | `Microsoft.Data.SqlClient` |
| SQLite | `Microsoft.Data.Sqlite` |
| PostgreSQL | `Npgsql` |
| MySQL | `MySql.Data` or `MySqlConnector` |

Avoid using `System.Data.OleDb` or `System.Data.Odbc` if cross-platform support is required, as these have limited or no support on Linux and macOS.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific issues such as:

- File path separator differences (`\` vs `/`)
- Case-sensitive file systems on Linux
- Missing Windows-only APIs

## 7. Review Nullable Reference Types

Modern .NET projects often enable nullable reference types by default:

```xml
<Nullable>enable</Nullable>
```

If this is enabled, review any nullable warnings in the build output and update your code accordingly to prevent potential `NullReferenceException` at runtime.

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your target runtime identifier (RID) as appropriate, for example `win-x64` or `osx-x64`. Use `--self-contained true` if you want to bundle the .NET runtime with the output.