# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only framework such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues, such as platform-specific API usage warnings (`CA1416`).

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or serialization behavior).

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any APIs that are Windows-only. Run a build with the platform target explicitly set:

```bash
dotnet build -p:PlatformTarget=AnyCPU
```

Look for `CA1416` warnings in the output. Any flagged APIs will need to be either replaced with cross-platform alternatives or guarded with runtime checks:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific code
}
```

## 5. Validate ADO-Specific Functionality

Since this project is named `AdoCore`, pay particular attention to any `System.Data` usage:

- Verify that database provider packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are explicitly referenced in the `.csproj` rather than relying on packages that were previously included transitively via .NET Framework.
- Test all database connection, query, and transaction logic against the target database to confirm correct behavior.

## 6. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. You can do this by inspecting the packages listed in the `.csproj` and cross-referencing them on [nuget.org](https://www.nuget.org):

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

## 7. Run on a Non-Windows Environment

To confirm cross-platform compatibility, run the application on Linux or macOS (or via WSL on Windows):

```bash
dotnet run --configuration Release
```

Observe any runtime exceptions that may not have surfaced during the build, particularly around file paths, registry access, or Windows-specific interop.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that output.