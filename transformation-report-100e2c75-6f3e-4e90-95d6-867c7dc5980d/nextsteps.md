# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removes certain APIs that were available in .NET Framework. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tools to scan for any runtime-level incompatibilities that do not surface as build errors.

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

## 5. Validate Runtime Behavior

Run the application locally and exercise its primary code paths. Pay particular attention to:

- **File system paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\`) remain.
- **Registry access**: The Windows registry is not available on Linux/macOS.
- **Windows-only APIs**: Any P/Invoke calls or `System.Windows` references will not function on non-Windows platforms.
- **Database connectivity**: If `AdoCore` implies ADO.NET usage, verify that the targeted database drivers (e.g., `Microsoft.Data.SqlClient`) are compatible with the new target framework.

## 6. Review NuGet Package Versions

Open the `.csproj` file and confirm all NuGet packages reference versions that support your target framework. You can check for outdated packages with:

```bash
dotnet list package --outdated
```

Update packages as needed, then re-run the build and tests.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment (no .NET runtime required on the target machine):

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) for your target environment.

## 8. Smoke Test the Published Output

Navigate to the `./publish` directory and run the output binary directly to confirm the published artifact behaves as expected before distributing it.