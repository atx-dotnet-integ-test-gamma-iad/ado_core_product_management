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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removes certain Windows-specific APIs that were available in .NET Framework. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` NuGet package if platform-specific calls are needed. Pay particular attention to:

- `System.Data` and ADO.NET usage (relevant given the `AdoCore` project name)
- Any usage of `ConfigurationManager` (replaced by `Microsoft.Extensions.Configuration`)
- Any usage of `System.Web` (not available in cross-platform .NET)

## 5. Validate NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure each package has a version that supports your target framework. You can check compatibility on [NuGet.org](https://www.nuget.org) or by running:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions compatible with your target framework.

## 6. Test on Target Platform

If the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that do not surface at compile time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your target runtime identifier (e.g., `win-x64`, `osx-x64`). Review the output in the `publish` folder before deploying to your target environment.