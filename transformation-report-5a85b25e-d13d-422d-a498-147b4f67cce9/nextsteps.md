# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues.

## 3. Review Removed or Replaced Dependencies

Check the `.csproj` file for any NuGet packages that were substituted during transformation. Verify that the versions referenced are compatible with your target framework by reviewing the [NuGet package compatibility](https://www.nuget.org/packages) page for each dependency.

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to confirm runtime behavior matches the original:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform equivalents.

## 5. Validate Platform-Specific Behavior

If the original project used any Windows-specific APIs (e.g., `System.Drawing`, registry access, COM interop, or WCF), verify that these either have cross-platform equivalents in place or are guarded with runtime checks:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific logic
}
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, environment variable differences, and any OS-specific runtime behavior.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) as needed. Review the output in the `publish` folder before deploying to the target environment.

## 8. Review Output Artifacts

Confirm that the published output contains all expected assemblies, configuration files, and assets. Compare against the original legacy build output to identify any missing files.