# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate subtle compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute the full test suite to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime, even when the build succeeds.

## 4. Verify Platform-Specific API Usage

Inspect the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` usage
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side components
- `AppDomain` usage beyond what is supported
- `BinaryFormatter` serialization, which is disabled by default in modern .NET

Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tooling to perform a compatibility scan if needed.

## 5. Run the Application and Perform Smoke Testing

Execute the application manually and walk through its primary workflows to confirm expected behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Pay attention to any runtime exceptions that would not have been caught at compile time.

## 6. Review Target Framework Moniker (TFM)

Open the `.csproj` file and confirm the target framework is set to an appropriate and currently supported version:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the project is still targeting `net6.0` or `net7.0`, consider updating to `net8.0`, which is the current Long Term Support (LTS) release.

## 7. Publish the Application

Once validation is complete, publish the application for deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate Runtime Identifier (RID) for your target platform, such as `linux-x64` or `osx-x64`.

## 8. Review Output Artifacts

Inspect the contents of the publish output directory to confirm all required assemblies, configuration files, and static assets are present before deploying to the target environment.