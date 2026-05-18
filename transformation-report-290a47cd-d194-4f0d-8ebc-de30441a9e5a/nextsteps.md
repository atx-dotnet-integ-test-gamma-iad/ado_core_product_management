# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Review any new warnings related to platform compatibility (e.g., `CA1416`).

## 5. Review NuGet Package Versions

Confirm all NuGet dependencies reference versions compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that previously targeted `.NET Framework`.

## 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, verify that settings have been migrated to `appsettings.json` or environment variables, as these are the standard configuration mechanisms in cross-platform .NET.

## 7. Perform Runtime Smoke Testing

Run the application locally and exercise its primary functionality:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Confirm that database connections, file I/O, and any other external integrations behave as expected across the target platforms.

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime <target-rid> --self-contained false
```

Replace `<target-rid>` with the appropriate Runtime Identifier, for example:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Review the contents of the `publish` output folder before deploying to the target environment.