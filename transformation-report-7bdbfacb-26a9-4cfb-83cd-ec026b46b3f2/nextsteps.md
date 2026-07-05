# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a clean restore to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not fully support your target framework.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no errors or warnings that may have been suppressed:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate compatibility concerns.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Verify Platform-Specific Code

Review the codebase for any APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to check include:

- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Database connection strings and driver compatibility (e.g., ensure you are using a cross-platform ADO.NET provider such as `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` where applicable)
- Any use of `ConfigurationManager` — replace with `Microsoft.Extensions.Configuration` if needed
- File path separators and environment-specific assumptions

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that do not surface during compilation.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your target runtime identifier (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Review Output Artifacts

Inspect the contents of the `publish` output directory to confirm all expected assemblies, configuration files, and dependencies are present before deploying to your target environment.