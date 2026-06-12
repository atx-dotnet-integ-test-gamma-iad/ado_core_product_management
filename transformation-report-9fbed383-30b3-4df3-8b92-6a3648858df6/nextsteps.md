# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the version of the .NET SDK you have installed. You can verify your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been resolved through compatibility fallbacks.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation errors:

```bash
dotnet build --configuration Release
```

Address any warnings that surface at this stage, particularly those related to obsolete APIs or platform compatibility analyzers (CA1416, etc.).

## 4. Run the Test Suite

If the solution contains a test project, execute all tests to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate runtime behavioral differences between the legacy .NET Framework and the new .NET runtime (e.g., changes in `System.Data`, encoding defaults, or globalization behavior).

## 5. Check for Platform-Specific API Usage

Run the .NET Compatibility Analyzer to surface any APIs that are not supported on all target platforms:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to any warnings prefixed with `CA1416` (platform compatibility) or `SYSLIB` (obsoleted .NET APIs).

## 6. Validate ADO.NET Functionality

Since the project is named `AdoCore`, it likely contains ADO.NET data access code. Verify the following:

- The database provider package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is explicitly referenced in the `.csproj` and is a version compatible with the new TFM.
- Connection string handling has not changed, particularly if `System.Configuration.ConfigurationManager` was used. If it was, confirm the `System.Configuration.ConfigurationManager` NuGet package is referenced, as it is no longer included by default.
- Any use of `DataSet`, `DataTable`, or `DataAdapter` is tested thoroughly, as serialization behavior for these types changed in .NET 5 and later.

## 7. Review Removed or Changed APIs

Check the code for usage of APIs that were removed or had behavioral changes in .NET Core and later:

- `AppDomain.GetCurrentThreadId()` — removed.
- `Thread.Abort()` — throws `PlatformNotSupportedException`.
- `BinaryFormatter` — disabled by default in .NET 5+ and removed in .NET 9.
- `System.Web` namespace — not available outside of ASP.NET Core.

The [.NET Upgrade Assistant compatibility report](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling can assist in identifying these.

## 8. Test on All Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any remaining platform-specific issues such as:

- File path separator assumptions (`\` vs `/`).
- Case-sensitive file system behavior on Linux.
- Windows-only registry or COM interop calls.

## 9. Publish the Application

Once validation is complete, publish the application for the target environment:

```bash
dotnet publish --configuration Release --runtime <RID> --self-contained false
```

Replace `<RID>` with the appropriate Runtime Identifier, for example `win-x64`, `linux-x64`, or `osx-x64`. Use `--self-contained true` if you require the .NET runtime to be bundled with the output.