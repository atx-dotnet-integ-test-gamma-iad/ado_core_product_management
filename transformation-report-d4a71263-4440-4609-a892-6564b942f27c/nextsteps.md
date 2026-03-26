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

Run a NuGet restore to confirm all packages resolve correctly under the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been replaced by inbox .NET APIs.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to obsolete APIs or platform compatibility analyzers (CA1416, etc.).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate runtime behavioral differences between .NET Framework and modern .NET (e.g., changes in globalization, reflection, or threading behavior).

## 5. Check for Platform-Specific API Usage

Run the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to identify any APIs that are Windows-only or otherwise platform-restricted:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review any `CA1416` warnings produced during the build step above. Wrap Windows-specific calls with runtime guards where necessary:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific code
}
```

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, and that `Microsoft.Extensions.Configuration` is being used to read them.

## 7. Verify Data Access Behavior

Since the project name suggests ADO.NET usage (`AdoCore`), confirm the following:

- Connection strings are correctly defined in the new configuration system.
- Any `System.Data` usage (e.g., `SqlConnection`, `DataAdapter`) compiles and behaves as expected.
- If `System.Data.OleDb` or `System.Data.Odbc` were used, note that these are Windows-only on .NET and will require the explicit NuGet packages:

```bash
dotnet add package System.Data.OleDb
dotnet add package System.Data.Odbc
```

## 8. Smoke Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues that do not surface at compile time:

```bash
dotnet run --configuration Release
```

## 9. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you want to bundle the .NET runtime with the output.